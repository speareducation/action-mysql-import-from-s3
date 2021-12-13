# Spear Core Database Setup Action
A GitHub action to pull mysqldump files from S3 and import them.

## Example:
```
jobs:
  build:
    runs-on: ubuntu-latest
    services:
      mysql_tdd:
        image: mysql:5.7
        env:
          MYSQL_ALLOW_EMPTY_PASSWORD: yes
          SQL_MODE: ""
        ports:
          - 3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3

      - id: setup-databases
        name: Setup Databases
        uses: speareducation/core-action-database-setup@master
        env:
          AWS_REGION: us-east-1
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        with:
          databases: db1 db2 db3
```