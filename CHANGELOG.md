Change Log
==========

All user visible changes to this project will be documented in this file. This project uses to [Semantic Versioning 2.0.0].




## [6.9.0-r2]· 2018-12-?

#### BC Breaks

- Deployment:
    - Improve Kurento healthcheck. Checking for the presence of an active web-socket connection on port 8888, use netstat(#2).
    - Disable Kurento autorestart via supervisord child.
    

#### Build


- Build kurento-media-server from [v6.9.0][1]
- Build kms-elements from [instrumentisto/kms-elements][2]


[1]: https://github.com/Kurento/kurento-media-server/releases/tag/6.9.0
[2]: https://github.com/instrumentisto/kms-elements
