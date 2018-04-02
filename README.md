# docker-android-studio

[Android Studio](https://developer.android.com/studio/) in a non-privileged docker container. It runs as a normal X11 window on a linux desktop.

## Things That Work

* Android Studio IntelliJ IDE
* Android emulator (hardware acceleration, sound, keyboard input)
    * Requires ``KVM``
    * Requires ``PulseAudio`` running on the host for sound
    * Hardware acceleration using OpenGL via ``/dev/dri``

## Not Yet Tested

* Plugging in an Android phone via USB

## Using

### Building

The current user id, current group id and KVM group id is baked into the container. Running the container as more than one user isn't supported. Note that on some systems the KVM [group id is dynamic](https://wiki.archlinux.org/index.php/QEMU#Could_not_access_KVM_kernel_module:_Permission_denied) and changes on boot which means the container will have to be rebuilt.

```bash
  $ bin/build
```

### Running

* Either create a file called ``.env`` (in the same directory as the ``Dockerfile``) or export the following environment variables:

Name|Description|Container Volume|Example
---|---|---|---
DATA_DIR|Directory containing android projects|/data|$HOME/AndroidStudioProjects
STUDIO_DIR|Directory to store persistent data such as Android SDK and Android Emulator files|/var/studio|$HOME/.android-dev

```bash
  $ bin/start
```

#### First Run

A wizard appears the first time the studio is run.

1. Complete Installation: ``Do not import settings``
1. Welcome: (next)
1. Install Type: ``Custom``
1. SDK Components Setup: Select what's required and change the Android SDK Location to: ``/var/studio/Android/Sdk``
1. Verify Settings: (next)
1. Emulator Settings: (finish)

## ToDo

* ``dbus`` errors when running Android Emulator.
* The package ``xserver-xorg-input-void`` pulls in a dependency which might change keyboard layout on the host system.
* Not having to rely on ``sudo docker``.
