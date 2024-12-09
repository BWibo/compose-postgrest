# compose-postgrest

[Postgres](https://www.postgresql.org/), [PostgREST](https://github.com/begriffs/postgrest), and [Swagger UI](https://github.com/swagger-api/swagger-ui) conveniently wrapped up with docker-compose.

Place SQL into the `initdb` folder, get REST!
Includes [world sample database](https://www.postgresql.org/ftp/projects/pgFoundry/dbsamples/world/).

Contains a simple front-end  demo application.

## Architecture

![Deployment Diagram](diagrams/deployment-diagram.png)

## Usage

### Start the containers

`docker-compose up -d`

### Tearing down the containers

`docker-compose down --remove-orphans -v`

## Demo Application

Located at <https://localhost/>

### SwaggerUI API docs

- <https://localhost/swagger/>

### Postgrest

- [Official API docs](https://docs.postgrest.org/en/v12/references/api.html)

#### Examples

- PostgREST API endpoint: <https://localhost/postgrest/>

Try things like:

- <https://localhost/postgrest/test>
- <https://localhost/postgrest/test?ts=gt.2023-01-01&ts=lt.2024-01-01>
- <https://localhost/postgrest/view_of_test>

Outdated examples:

- <https://localhost/postgrest/city?district=like.*Island>
- <https://localhost/postgrest/city?district=like.*Island&population=lt.1000&select=id,name>
