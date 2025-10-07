# JS8Call Developer's Submodule Repository

- This repository is only for JS8Call developers to build and package pre-built libraries for JS8Call. It is not intended for end users
to build the code.
- The base repository contains the source code for FFTW-3.3.10 and Boost 1.88.0
- Hamlib v4.6.4, libusb-1.0.29 are obtained as submodules with `git submodule update --init --recursive' by
running the BUILD.sh script for MacOS. Building Qt 6.8.3 is optional.
- Note the script will ask if you are building universal or architecture-dependent libraries. If you are on an Intel Mac you must select
no or the build will fail.

# Building and Creating a JS8Call Library Package
- To build a library package you must create the proper directory structure on your development machine. The following command will
accomplish this: `sudo mkdir /usr/local/js8lib && chown <your_username> /usr/local/js8lib`
- cd into your development root folder which can be anything you wish and clone this repository with:
```
git clone https://github.com/Chris-AC9KH/js8lib.git submodules
```
- cd into submodules and run the BUILD.sh script with `./BUILD.sh`. If the build is successful it will create a gzipped tar archive of the
library build in the root of your development folder. Depending on the capabilities of your build machine this can take a long time.

-Note: the script will check out the 6.8.3 Qt branch by default. If you wish to build a different version of Qt, modify the script before running it to check out the version of Qt that you want.

- After the build completes you can validate the library build by building JS8Call with: `-prefix /usr/local/js8lib` for your build.

- If /usr/local/js8lib gets deleted or over-written at some point you can replace it with the packaged archive by unpacking it and use
`sudo mv ./js8lib /usr/local/ && sudo chown <your-user-name> /usr/local/js8lib`
