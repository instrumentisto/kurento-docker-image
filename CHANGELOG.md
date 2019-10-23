Change Log
==========

All user visible changes to this project will be documented in this file. This project uses to [Semantic Versioning 2.0.0].




## [6.12.0-r3]· 2019-10-23

#### Build

- Build kurento-media-server from [v6.12.0][5]




## [6.10.0-r3]· 2019-03-18

#### Build

- Build image from [Ubuntu Bionic Beaver][3]
- Build kurento-media-server from [v6.10.0][4]




## [6.9.0-r2]· 2019-01-22

#### BC Breaks

- Deployment:
    - Disable Kurento autorestart via supervisord child.
    
#### Build

- Build kurento-media-server from [v6.9.0][1]
- Use custom kms-elements from [instrumentisto/kms-elements][2]




## [6.8.1-r1]· 2018-12-14

#### BC Breaks

- Deployment:
    - Improve Kurento healthcheck. Checking for the presence of an active web-socket connection on port 8888, use netstat(#2).




[1]: https://github.com/Kurento/kurento-media-server/releases/tag/6.9.0
[2]: https://github.com/instrumentisto/kms-elements
[3]: http://releases.ubuntu.com/18.04/
[4]: https://github.com/Kurento/kurento-media-server/releases/tag/6.10.0
[5]: https://github.com/Kurento/kurento-media-server/releases/tag/6.12.0
