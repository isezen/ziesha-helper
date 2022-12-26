# Ziesha-Helper
_Ziesha Helper_ is a tool to install and manage your Ziesha infrastructure. You can

* install bazuka, uzi-miner, zoro and uzi-pool
* start/stop/restart Ziesha tools
* get summary reports about your tools
* and your tool can be restarted if an error happens.

# How to install?

To install _Ziesha Helper_, just copy&paste following command in your terminal window. It will make required adjustments and install _Ziesha Helper_ on your system.

```sh
curl -s https://raw.githubusercontent.com/isezen/ziesha-helper/main/ziesha | bash && . ~/.profile
```

# How to use?

After installation, type `ziesha` (and press `ENTER`) on your command line to see _Ziesha Helper_ command parameters. You can get detailed usage information about each command by typing `ziesha COMMAND -h`. For instance, to get informationm how to install a Ziesha tool, type `ziesha install -h`.

```
ℤiesha Helper v0.1

  Made with ❤️  by pentafenolin (2022)
  ● Discord: pentafenolin#9413
  ● Twitter: @pentafenolin (Follow me! ^_^)
  ● Github : https://github.com/isezen

  DESCRIPTION:
    Manage Ziesha-network infrastructure.
    For more info, type 'ziesha COMMAND -h'

  OPTIONS:
    -h | --help     : Shows this message
    -v | --version  : Show Ziesha Helper version

  COMMANDS:
    install    : Install a Ziesha tool
    update     : Update a Ziesha tool
    remove     : Remove/uninstall a Ziesha tool
    list       : List installed tools
    log        : Show log of a Ziesha tool
    set        : Set a variable
    get        : Get a variable
    download   : Download zoro dat files
    init       : Initialize bazuka
    run        : Run selected tool
    reset      : Reset bazuka and wallet
    start      : Start a service
    stop       : Stop a service
    restart    : Restart a service
    status     : Show status
    summary    : Show summary

  USAGE EXAMPLES:
    $ ziesha install bazuka
    $ ziesha remove zoro
    $ ziesha set discord-handle MYHANDLE
    $ ziesha start uzi-pool
```

# How to install?

## Install Rust

It is easier to install rust after installing _Ziesha Helper_. You just need to type following command to install rust.

```sh
ziesha install rust
```

# Install Bazuka

Just type `ziesha install bazuka`. This command will download required source files from github, save them under `.local/ziesha/bazuka` folder and compile using rust toolchain. Installing other tools are easy as installing Bazuka. To install uzi-miner, just type `ziesha install uzi-miner`.

# Start Bazuka

Before starting Bazuka, we need to set some settings to be able to join testnet phase of Ziesha Network. Following command will set your discord handle to track your Bazuka node status.

```sh
ziesha set --discord-handle pentafenolin#1234
```

Then, you need to `init` your bazuka environment before starting bazuka. This command is completely same as `bazuka init ...` command.

```sh
ziesha init --network NETWORK_NAME --bootstrap X.X.X.X:8765 --mnemonic "YOUR MNEMONIC WORDS"
```

where `NETWORK_NAME` is your testnet network name, `X.X.X.X` is your bootstrap IP and `YOUR MNEMONIC WORDS` are your previous mnemonics. If you are first time setting up a bazuka node, you won't have any mnemonics, bazuka will give your mnemonics after initialization. Don't forget to save them somewhere safe.

Through out testnet phase, you might be required to change the network name. You can change it by the command below:

```sh
ziesha set --network NEW_NETWORK_NAME
```

After setting up, you can start bazuka just by typing:

```sh
ziesha start bazuka
```

This command will start bazuka in the background. You can see the log output just by typing;

```sh
ziesha log bazuka
```

You need to press `CTRL+C` to quit the log output screen.

Also, you can watch a summary report of your bazuka node by typing:

```sh
watch -c "ziesha summary"
```

# Start Uzi-Miner

Uzi-Miner is a required tool to start mining in Ziesha Network. You can install uzi-miner just by typing the command below:

```sh
ziesha install uzi-miner
```

After installation, we need to set up some variables for uzi-miner. You can define number of CPU threads by `nthreads` option and access token required by the pool `pool-token` option. 

```sh
ziesha set --nthreads 1
ziesha set --pool-token MUsYPsZiLnpKqM1ykc6bTZypv3KX5i
```

After setting up those options, you can start mining by typing `ziesha start uzi-miner` and see the log output by typing `ziesha log uzi-miner`. You will need to press `CTRL+C` to quit the log output screen.