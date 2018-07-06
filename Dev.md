# How to build
- Install [qt sdk](https://www.qt.io/download) for your platform.
- Build and install [qtleveldb](https://github.com/paulovap/qtleveldb)
  
  Note: You will need to change some header paths. When you get error just adjust the path of the erroring header.
- Build the project using qt creator or with qmake.
- App dists are made using macdeployqt and [linuxdeployqt](https://github.com/probonopd/linuxdeployqt)
