name: CI

on:
  push:

jobs:
  test:
    strategy:
      matrix:
        node: ['10.x', '12.x']
        os: [ubuntu-latest]

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v1
      - uses: actions/setup-node@v1
        with:
          node-version: ${{ matrix.node }}

      - run: npm install -g yarn

      - id: yarn-cache
        run: echo "::set-output name=dir::$(yarn cache dir)"
      - uses: actions/cache@v1
        with:

          path: ${{ steps.yarn-cache.outputs.dir }}
          key: ${{ matrix.os }}-yarn-${{ hashFiles('**/yarn.lock') }}
          restore-keys: |
            ${{ matrix.os }}-yarn-

      - run: yarn
      - run: yarn lint
      - run: yarn test
  deploy-ganache:

    runs-on: ubuntu-latest
    name: Deploy to Ganache
    services:
      ganache:

        image: trufflesuite/ganache-cli
        ports:
          - 8545:8545
    steps:
      - uses: actions/checkout@v1
      - uses: actions/setup-node@v1
        with:
          node-version: '12.x'
      - run: npm install -g yarn
      - id: yarn-cache
        run: echo "::set-output name=dir::$(yarn cache dir)"
      - uses: actions/cache@v1
        with:
          path: ${{ steps.yarn-cache.outputs.dir }}
          key: ${{ matrix.os }}-yarn-${{ hashFiles('**/yarn.lock') }}
          restore-keys: |
            ${{ matrix.os }}-yarn-
      - name: Create .env
        run: |
          echo "INFURA_API_KEY=$INFURA_API_KEY" >> .env
          echo "MNEMONIC=$MNEMONIC" >> .env
        shell: bash
        env:
          INFURA_API_KEY: ${{ secrets.INFURA_API_KEY }}
          MNEMONIC: ${{ secrets.MNEMONIC }}
      - run: yarn

      - run: yarn compile
      - run: yarn truffle-compile
      - run: yarn replace-factory
      - run: yarn truffle-migrate
  deploy-ropsten:

    runs-on: ubuntu-latest
    name: Deploy to Ropsten
    if: github.ref == 'refs/heads/staging'
    steps:

      - uses: actions/checkout@v1
      - uses: actions/setup-node@v1
        with:

          node-version: '12.x'
      - run: npm install -g yarn
      - id: yarn-cache
        run: echo "::set-output name=dir::$(yarn cache dir)"
      - uses: actions/cache@v1
        with:

          path: ${{ steps.yarn-cache.outputs.dir }}
          key: ${{ matrix.os }}-yarn-${{ hashFiles('**/yarn.lock') }}
          restore-keys: |
            ${{ matrix.os }}-yarn-
      - name: Create SSH key
        run: |
          mkdir -p ~/.ssh/
          echo "$GITHUB_PRIVATE_KEY" | base64 -d  > ~/.ssh/id_rsa
          sudo chmod 600 ~/.ssh/id_rsa
        shell: bash
        env:
          GITHUB_PRIVATE_KEY: ${{ secrets.READ_ONLY_GITHUB_SSH_KEY }}
      - name: Create .env
        run: |
          echo "INFURA_API_KEY=$INFURA_API_KEY" >> .env
          echo "MNEMONIC=$MNEMONIC" >> .env
        shell: bash
        env:
          INFURA_API_KEY: ${{ secrets.INFURA_API_KEY }}
          MNEMONIC: ${{ secrets.MNEMONIC }}
      - run: yarn
      - run: yarn compile
      - run: yarn truffle-compile
      - run: yarn replace-factory
      - run: yarn truffle-migrate-ropsten
