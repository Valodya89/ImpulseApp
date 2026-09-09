# Impuls

## Mimo backend documentation

Authoritative backend documentation is served by the mimo-knowledge MCP
server. Before writing or changing any integration with Mimo backend services
(endpoints, request/response fields, enums, error codes, auth, payments,
wallet, rentals, EV charging), call its search_docs / read_doc tools and
follow what the documentation says. Never guess endpoint paths, field names,
enum values or error codes — if the docs do not answer, say so instead of
inventing. Every answer from this server carries the source repository, file
path and commit SHA — prefer the newest commit and cite the source.
