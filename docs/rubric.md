# Rubric — ansible-role-dev-stack

Criteria that need judgment. Answer each with evidence from the diff.

| Criterion | Severity |
| --- | --- |
| A download behind a proxy runs as the connecting user and with `curl`: `become` drops the proxy variables, and `get_url` fails behind a TLS-inspecting proxy. | Important |
| A new option is off by default, unless every consumer needs it. | Important |
| The role never sets up a credential: no login, token or key of the operator. | Critical |
