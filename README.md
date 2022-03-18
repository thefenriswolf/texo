```

████████╗███████╗██╗  ██╗ ██████╗ 
╚══██╔══╝██╔════╝╚██╗██╔╝██╔═══██╗
   ██║   █████╗   ╚███╔╝ ██║   ██║
   ██║   ██╔══╝   ██╔██╗ ██║   ██║
   ██║   ███████╗██╔╝ ██╗╚██████╔╝
   ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝ 
   
```

# texo
A simple build system based on [bash, elisp, rust] and nixpkgs.

## requirements

- [bash, emacs, libc]
- nixpkgs
- curl

## usage
1. copy texo into your project
2. edit texo source file and fill out the config section
3. create dev environment

```bash
$ ./texo.sh init
```
3. enter dev evironment

```bash
$ ./texo.sh sh
```

4. start coding & compile your project with:

```bash
$ ./texo.sh com
```
