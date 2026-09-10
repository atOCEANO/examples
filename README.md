<h1>OCEΛNO <small><code>examples</code></small></h1>


<div style="padding-top: 0px;">
  <a href="https://www.python.org/downloads/"><img src="https://img.shields.io/badge/python-3.10+-blue.svg" alt="Python 3.10+" /></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT" /></a>
</div>

<sub>
  <b>Introduction</b> &nbsp;•&nbsp;
  <a href="00-data.ipynb">The data</a> &nbsp;•&nbsp;
  <a href="01-backtest.ipynb">Backtest</a> &nbsp;•&nbsp;
  <a href="02-search.ipynb">Parameter search</a> &nbsp;•&nbsp;
  <a href="03-rl.ipynb">Reinforcement learning</a> &nbsp;•&nbsp;
  <a href="04-engine.ipynb">Raw engine</a>
</sub>

<br>
<br>
<br>
<br>

## Introduction

Five notebooks, each **a runnable starting point for one way of driving the stack**. Copy one and replace the part that is yours, the rule, the reward, or just the symbol, keeping everything around it. They open the same way, so the difference between any two of them is the surface being demonstrated rather than the scaffolding around it.

Three of the five carry a trading rule, and it is the same rule each time, a moving average crossover, with a trailing stop added for the exit in `04`. It is that simple because it is here to give the tools something to run, not to be traded. The other two carry none. `00` never simulates anything, and `03` has no rule by design: reinforcement learning replaces it with an observation, a reward and an action space, and what steps the environment there is a random baseline and a PPO agent measured against it.

What each notebook is demonstrating is the surface rather than what it runs on: how a frame arrives and what it carries, what a run costs, what a search is worth, how an environment steps, and what the engine looks like with nothing in front of it.

Each one runs and its outputs are committed, so the frame shapes, the metadata, the warnings and the charts are readable without starting a kernel. The numbers they print are whatever the run produced, including when that is a loss.

Two projects stand behind them. [`exchange-router-service`](https://github.com/atOCEANO/exchange-router-service) normalizes public crypto market data behind one schema, whichever exchange served it, and [`embeddable-market-simulation-library`](https://github.com/atOCEANO/embeddable-market-simulation-library) runs the simulation over it. **The router has to be running.** Nothing here reads a committed data file: the bars are pulled live, and a pinned anchor with a pinned bar count makes the window reproducible without freezing a parquet into git.

<br>
<br>

## Running It

### Everything in containers

The router is built from a checkout beside this one, so clone it first:

```bash
git clone https://github.com/atOCEANO/exchange-router-service.git ../exchange-router-service
docker compose up
```

That builds both images, waits for the router's `/status` healthcheck to pass, and only then starts JupyterLab on `http://127.0.0.1:8888` with no token to paste. This folder is mounted into the container, so anything you edit lands here. Nothing is published beyond loopback.

A sibling checkout rather than a remote git context, because **BuildKit cannot fetch git over HTTPS on every machine** and fails claiming a public repository needs credentials. Both compose files also declare the same `oceano` project, so the two stacks share a network and a router started from the router's own repo is reachable here by service name.

### On your own Python

```bash
pip install --index-url https://download.pytorch.org/whl/cpu torch
pip install -r requirements.txt jupyterlab ipywidgets
jupyter lab
```

`requirements.txt` pins the two libraries and nothing else, so the notebook server and its widgets are named on the command line rather than baked into the file. Torch goes first, and from pytorch's CPU index, for the same reason the Dockerfile does it that way: leave it out and resolving the `sb3` extra takes the CUDA build off PyPI instead, which is gigabytes of runtime nothing here can reach.

The router runs separately, and in its own environment. From an `exchange-router-service` checkout:

```bash
pip install -r requirements.txt
uvicorn src.main:app --port 8040
```

Compose is the path the notebooks are written for. The image carries both libraries and the healthcheck holds the notebook server back until `/status` answers, so the environment is up before a cell runs. The pip route reaches the same state by hand and the notebooks cannot tell the difference.

What they will not do is build the environment for you. Each one checks that the libraries it imports are there and that a router answers, then **fails by naming the command that fixes it**, rather than cloning a service into your working directory or leaving a stray process holding a port after a kernel restart.

<br>
<br>

## The Notebooks

The four that simulate are ordered by how much of the decision you hand over, and then taking all of it back. You write the rule, then a search picks its parameters, then you stop writing a rule at all and define what an agent sees and what it is paid for instead, and then the framework goes away and you own the loop.

| Notebook | What it covers |
| :--- | :--- |
| [00-data.ipynb](00-data.ipynb) | The router by itself: writing a time window in Unix milliseconds, the raw JSON against the frame the SDK builds from it, the two places volume misleads you, and pulling a whole venue in one call. |
| [01-backtest.ipynb](01-backtest.ipynb) | A `Strategy` class with `init`, `next` and a `marks()` method that keeps a legend from going stale, costs set deliberately, `decompose` to see which failure a loss was, and how to drive the chart rather than just draw it. |
| [02-search.ipynb](02-search.ipynb) | `tune` over a parameter space, the distance between the best in-sample score and that same setting on bars no trial ever saw, and `walk_forward` refitting along the series to ask that question five times instead of once, with each window shaded on the chart and the parameters it chose carried underneath it. |
| [03-rl.ipynb](03-rl.ipynb) | A vectorized Gymnasium env: your observation, your reward, your action decoding, per-environment cost draws, and the same-step autoreset that fails silently. Then PPO trained on it through the SB3 adapter, and measured against random on bars it never saw. |
| [04-engine.ipynb](04-engine.ipynb) | The raw `reset` / `step` / `done` loop, and a trailing stop, which is the shape of rule that cannot be precomputed at any speed. Its chart carries the six settings that produced it, so the saved file explains itself. |

Read `00` first. The other four assume it and carry only a short fetch.

<br>
<br>

## What Every Notebook Shares

Two sections open every notebook, and they are the two worth keeping when you copy one. They vary only in what that notebook needs: `00` never imports emsl at all, `02` also checks for optuna, `03` checks for gymnasium, torch and stable-baselines3, and `03` pulls perpetual bars where the rest pull spot.

| Section | What it does |
| :--- | :--- |
| Setup | Checks and opens, installs and starts nothing. It confirms the libraries that notebook actually imports and that a router answers, then **fails by naming the command that fixes it**. It prints the versions it found rather than the ones it expected. |
| The candles | The venue, the symbol, the interval and the window, in the same cell as the one `get_candles` that reads them, so changing market is one string. |

Everything after that is the surface being demonstrated, so the sections differ.

<br>
<br>

## Configuration

One environment variable, read by every notebook.

| Name | Default | Set it when |
| :--- | :--- | :--- |
| `ROUTER_URL` | `http://127.0.0.1:8040` | The router is somewhere other than loopback. Compose sets it to the service address on its own. |

All five run on the pinned set, the training run in `03-rl.ipynb` included. Gymnasium arrives as a dependency of emsl rather than as an extra, and the `sb3` extra adds stable-baselines3.

**Torch is why the image is a couple of gigabytes.** It is installed from the Dockerfile rather than from `requirements.txt`, and from pytorch's own CPU index, because the default wheel on PyPI carries a CUDA runtime of several gigabytes that nothing here can reach. Installing it before the requirements is what makes resolving the `sb3` extra find it already satisfied.

<br>
<br>

## Notes

**The `start` parameter anchors the end of a window, not its beginning.** Every adapter implements it that way, so a `start` of the first of January asking for a year of bars returns the year before it, silently, with no error raised and every number downstream quietly wrong. The notebooks name that constant `ANCHOR` for that reason.

**Candle responses are not cached.** The router caches exchange metadata but goes upstream for every candle request, so restarting a kernel refetches. For one year of hourly bars that is a handful of paginated requests and a few seconds.

**Charts do not render on GitHub.** `emsl.chart` draws into an iframe and GitHub strips iframes out of notebook output. Run the notebooks to see them, or open them in JupyterLab or VS Code.

<br>
<br>

## Scope

Starting points, not a strategy library. Nothing here is meant to be imported, and nothing in it is meant to be traded, rule or reward. They show what each surface expects and what it gives back.
