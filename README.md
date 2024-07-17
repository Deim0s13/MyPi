# Installing and Configuring my Raspberry Pi with Pihole

## Install git

```bash
sudo apt-get install git
```

## Clone this git respository

```bash
git clone https://github.com/Deim0s13/MyPi.git
```

## Make the scripts executable

```bash
cd MyPi
chmod +x pre-reqs.sh
```

## Run the pre-reqs script

The pre-reqs script will install and configura all the necessary prerequisites for running Pihole on a Raspberry Pi

'Note: Change the IP address values to the static IP address you intend to use.

```bash
sudo ./pre-reqs.sh
```

