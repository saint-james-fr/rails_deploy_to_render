## Deploying on Render for Rails app

This follows Render recommendations from their website: https://render.com/docs/deploy-rails
Then initialize with free settings
Then ask if you wanna commit/create a remote repo/open render
Thanks to Anne Ly for the tutorial.
Enjoy!

## render.yaml configuration


```yaml
databases:
  - name: postgres_#{app_name}
    plan: free
    ipAllowList: []

services:
  - type: web
    name: #{app_name}
    plan: free
    env: ruby
    buildCommand: './bin/render-build.sh'
    startCommand: bundle exec rails s
    envVars:
      - key: RAILS_MASTER_KEY
        sync: false
      - key: DATABASE_URL
        fromDatabase:
          name: postgres_#{app_name}
          property: connectionString
  - type: redis
    name: redis_#{app_name}
    ipAllowList: []
    plan: free
    maxmemoryPolicy: noeviction
"
```
