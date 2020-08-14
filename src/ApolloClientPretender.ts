import { parse } from 'graphql/language/parser'
import { print } from 'graphql/language/printer'
import { ApolloLink, Observable, RequestHandler, DocumentNode } from 'apollo-link'
import { ApolloCache, DataProxy } from 'apollo-cache'
import ApolloCachePretender from './ApolloCachePretender'
import ApolloStateChangeEvent from './ApolloStateChangeEvent'

const requestHandler: RequestHandler = (operation, _forward) => {
  return new Observable(observer => {
    const body = {
      variables: operation.variables,
      extensions: operation.extensions,
      operationName: operation.operationName,
      query: print(operation.query)
    }
    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body)
    }
    fetch('/request', options)
      .then(response => {
        if (response.ok) {
          return response.json()
        }
        throw Error(response.statusText)
      })
      .then(json => observer.next(json))
      .then(() => observer.complete())
      .catch(error => observer.error(error))
  })
}

export default class ApolloClientPretender implements DataProxy {
  public readonly version = '2.0.0'
  public readonly link: ApolloLink = new ApolloLink(requestHandler)
  public readonly cache: ApolloCache<object> = new ApolloCachePretender(this.startListening.bind(this))

  private devToolsHookCb?: (event: ApolloStateChangeEvent) => void
  private eventSource?: EventSource

  public readQuery(options: DataProxy.Query<unknown>, optimistic = false): null {
    return this.cache.readQuery(options, optimistic)
  }

  public readFragment(options: DataProxy.Fragment<unknown>, optimistic = false): null {
    return this.cache.readFragment(options, optimistic)
  }

  public writeQuery(options: DataProxy.WriteQueryOptions<unknown, unknown>): void {
    this.cache.writeQuery(options)
  }

  public writeFragment(options: DataProxy.WriteFragmentOptions<unknown, unknown>): void {
    this.cache.writeFragment(options)
  }

  public writeData(options: DataProxy.WriteDataOptions<unknown>): void {
    this.cache.writeData(options)
  }

  public startListening(): void {
    this.eventSource = new EventSource('/events')
    this.eventSource.onmessage = message => {
      const event = parseApolloStateChangeEvent(message.data)
      this.devToolsHookCb?.(event)
    }
    this.eventSource.addEventListener('stdout', event => onLogMessageReceived(event as MessageEvent))
    this.eventSource.addEventListener('stderr', event => onLogMessageReceived(event as MessageEvent))
  }

  public stopListening(): void {
    this.eventSource?.close()
  }

  public __actionHookForDevTools(cb: (event: ApolloStateChangeEvent) => void): void {
    this.devToolsHookCb = cb
  }
}

function onLogMessageReceived(event: MessageEvent): void {
  const color = event.type === 'stdout' ? 'cadetblue' : 'tomato'
  console.log(`%c${event.data}`, `color: ${color}`)
}

function parseApolloStateChangeEvent(json: string): ApolloStateChangeEvent {
  const event = JSON.parse(json)
  for (let query of Object.values(event.state.queries) as [{document: string | DocumentNode}]) {
    query.document = parse(query.document as string)
  }
  for (let mutation of Object.values(event.state.mutations) as [{mutation: string | DocumentNode}]) {
    mutation.mutation = parse(mutation.mutation as string)
  }
  return event as ApolloStateChangeEvent
}
