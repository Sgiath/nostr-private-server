# Nostr

Nostr client intended to be run on server for just one user

## How to run

1. Create your `.env` file

   ```bash
   cp template.env .env
   ```

2. Paste your private key to the `.env` file
3. Export the `.env` - the easies way is to install [direnv](https://direnv.net/) which will do it
   automatically for you (you need to [enable](https://direnv.net/man/direnv.toml.1.html#codeloaddotenvcode) exporting `.env` files)
4. Install deps `mix deps.get`
5. Start Phoenix server `mix phx.server`
6. Go to <http://localhost:4000/nostr>
