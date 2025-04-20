# neorv32_bench
> Test the beloved core!

This project aims to tests the ins and outs of the marvelous [NEORV32](https://github.com/stnolting/neorv32) RISC-V core.

Each subfolder in `tests` represents a testing _strategy_ for the little core and contains (or will contain) numerous testbenches.
 - Strategy `unit` contains plain old testbenches that test each entity individually.
 - In `tool`, various simulators have a go at a simple simulation to ensure the core is understood by the respective tool.
 - For `size`, the _litex_-compatible toplevel is synthesized down to LUT6s and FFs with Yosys and the various configurations can quantitatively be compared.
 - Coming soon: strategy `formal` will be added to hunt down even the trickiest bugs using formal verification.
 - ... and maybe more in the future?


## How to run the tests

Each subfolder contains a set of `Makefile`s that allow the tests to be run in a few different tools. The semantic is mostly `make <tool> test`. Run `make help` to get the list of supported tools and targets for the _testing strategy_.

> [!NOTE]
> To support all the different EDA tools the makefiles use a rather convoluted system built from makefiles, docker containers and duct tape. The provided [devcontainer configuration](.devcontainer/devcontainer.json) uses pre-built containers from my [container_builder](https://github.com/NikLeberg/container_builder) project. If you have a particular EDA tool already installed you may also just call its makefile directly. E.g. if you have GHDL installed, run `make -f makefile.ghdl test`.


## Links

### Tools
 - GHDL: https://github.com/ghdl/ghdl
 - NVC: https://www.nickg.me.uk/nvc/
 - Yosys: https://yosyshq.net/yosys/
 - ModelSim / Questa: https://eda.sw.siemens.com/en-US/ic/modelsim/

### Similar Projects:
 - Testing the NEORV32 with VUnit: https://github.com/stnolting/neorv32-vunit


## License
[MIT](LICENSE) © N. Leuenberger.
