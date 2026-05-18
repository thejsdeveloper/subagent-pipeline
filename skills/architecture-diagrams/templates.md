# Architecture Diagram Templates

Use these as starting points. Replace generic labels with domain names from the codebase or proposed system. All diagrams use plain Mermaid (`flowchart` or `sequenceDiagram`), not C4-specific Mermaid syntax.

## System Context (Level 1)

```mermaid
flowchart LR
  person[Person]
  system[Software System]
  external[External System]

  person -->|uses| system
  system -->|calls| external
```

## Container (Level 2)

```mermaid
flowchart LR
  person[Person]
  web[Web App]
  api[API Service]
  db[(Database)]

  person -->|HTTPS| web
  web -->|calls| api
  api -->|reads/writes| db
```

## Component (Level 3)

Container: API Service

```mermaid
flowchart LR
  controller[Controller]
  service[Application Service]
  repository[Repository]
  db[(Database)]

  controller -->|uses| service
  service -->|uses| repository
  repository -->|reads/writes| db
```

## Dynamic (sequence)

```mermaid
sequenceDiagram
  actor Person
  participant Web as Web App
  participant API as API Service
  participant DB as Database

  Person->>Web: Submit request
  Web->>API: Validate and send command
  API->>DB: Persist data
  DB-->>API: Confirm write
  API-->>Web: Return result
  Web-->>Person: Show outcome
```

## Deployment

```mermaid
flowchart LR
  subgraph network[Cloud / Network]
    web[Web Runtime]
    service[Service Runtime]
    db[(Managed DB)]
  end

  web -->|internal HTTP| service
  service -->|database connection| db
```
