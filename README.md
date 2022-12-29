

<!-- ABOUT THE PROJECT -->
## About The Project

Twio is a script suite that provide comprehensive and reliable filesystem and docker management. It enables a user to stage, run and stop docker applications, as well as to backup and recover data with remote and local deployment configurations. Additional logging functionality enables users to track and monitor their deployments.

<!-- GETTING STARTED -->
## Getting Started

Follow the provided .env example to set up your project's working directory, security features, backup settings, and more. 

Once your .env file is configured, simplyt execute twio.py to run the program.

### Prerequisites

Twio relies on a few 3rd-party applications for proper operation. Install the following dependencies to begin.

1. Python package dependencies:
   ```sh
   pip install py-docker *TBD*
   ```

### Installation

1. Clone the repo and change into the repo directory:
   ```sh
   git clone https://github.com/twwhite/twio.git
   cd twio
   ```

3. Copy and modify the provided _.env.example_ file (see [Twio Environment Variables](https://) for details):
   ```
   cp .env.example .env
   vim .env
   ```
4. Run the main script, twio.py:
   ```
   python3 twio.py
   ```

<!-- USAGE EXAMPLES
## Usage

Use this space to show useful examples of how a project can be used. Additional screenshots, code examples and demos work well in this space. You may also link to more resources.

_For more examples, please refer to the [Documentation](https://example.com)_

 -->


<!-- ROADMAP -->
## Roadmap
- Filesystem staging
- App staging
- App running
- App stopping
- Backups & remote deployment
- Logging
 
- [x] Filesystem staging
- [x] App staging
- [ ] App start / stop functionality
- [ ] Backup & remote deployment
- [ ] Recovery
- [ ] Logging

See the [open issues](https://github.com/twwhite/twio/issues) for a list of TODO and known issues.


<!-- CONTRIBUTING -->
## Contributing
Feel free to make any contributions you see fit. 

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.


<!-- CONTACT -->
## Contact

Tim White - [@twwhite](https://github.com/twwhite) - tim@timwhite.io

Project Link: [https://github.com/twwhite/twio/](https://github.com/twwhite/twio/)



