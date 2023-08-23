# Installation

If you want to modify and build a new System Architecture diagram. You will need to install the python package
`Diagrams` (https://diagrams.mingrammer.com/docs/getting-started/installation).

`Diagrams`requires:
* Python 3.6 or higher 
* Graphviz

## Install Graphviz
MacOS users can download the Graphviz via brew install graphviz if you're using Homebrew. Similarly, Windows users with 
Chocolatey installed can run choco install graphviz.

## Install Diagrams
### using pip (pip3)
```shell
pip install diagrams
``` 

### using poetry
```shell
poetry add diagrams
```

## Building the Terarium System Architecture Diagram
```shell
python system-arch.py
```
