# Dockerfile REPL - UI
Single file bash script to get a REPL like env for Dockerfiles on web.

## Install

1. Install `busybox` with `httpd` applet.
2. Install [`ttyd`](https://github.com/tsl0922/ttyd/releases/) for interactive terminal.
3. Download `drp.sh` and place it inside your `PATH`.

## Usage

1. Get inside directory where you want to build your dockerfile.
2. Run `drp.sh path/to/Dockerfile`. Dockerfile must also be inside build directory's path (can be in sub directories too).

# Screenshots
### UI
<img src="/screenshots/sc-ui.png" alt="Web UI"/>

### Terminal(ttyd)
<img src="/screenshots/sc-term.png" alt="Terminal View"/>

