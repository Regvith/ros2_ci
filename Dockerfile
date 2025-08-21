# ROS 2 Humble on Jammy (desktop includes Gazebo Classic)
FROM osrf/ros:galactic-desktop

# Locale & noninteractive apt

ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    ROS_DISTRO=galactic \
    LIBGL_ALWAYS_SOFTWARE=1

# Core tools, colcon, Gazebo, URDF/xacro, publishers, TF, RViz, and NAV2
RUN set -eux \
 && apt-get update \
 && apt-get -y upgrade \
 && apt-get install -y --no-install-recommends \
      ca-certificates git build-essential cmake \
      python3-pip python3-rosdep python3-colcon-common-extensions \
      # Gazebo Classic + ROS integration
      ros-${ROS_DISTRO}-gazebo-ros-pkgs \
      # URDF/xacro + state publishers
      ros-${ROS_DISTRO}-xacro \
      ros-${ROS_DISTRO}-urdf \
      ros-${ROS_DISTRO}-robot-state-publisher \
      ros-${ROS_DISTRO}-joint-state-publisher \
      ros-${ROS_DISTRO}-joint-state-publisher-gui \
      # TF
      ros-${ROS_DISTRO}-tf2-ros \
      ros-${ROS_DISTRO}-tf2-tools \
      # Visualization / tools
      ros-${ROS_DISTRO}-rviz2 \
      ros-${ROS_DISTRO}-rqt \
      # ros2_control stack
      ros-${ROS_DISTRO}-ros2-control \
      ros-${ROS_DISTRO}-ros2-controllers \
      # Navigation2 (Galactic-safe subset)
      ros-${ROS_DISTRO}-navigation2 \
      ros-${ROS_DISTRO}-nav2-bringup \
      ros-${ROS_DISTRO}-nav2-map-server \
      ros-${ROS_DISTRO}-nav2-amcl \
      ros-${ROS_DISTRO}-nav2-costmap-2d \
      ros-${ROS_DISTRO}-nav2-planner \
      ros-${ROS_DISTRO}-nav2-controller \
      ros-${ROS_DISTRO}-nav2-behavior-tree \
      ros-${ROS_DISTRO}-nav2-waypoint-follower \
      ros-${ROS_DISTRO}-nav2-lifecycle-manager \
      # Optional
      ros-${ROS_DISTRO}-slam-toolbox \
      xvfb x11-apps \
      libgtest-dev libgmock-dev \
 && rm -rf /var/lib/apt/lists/*
# Build and install gtest/gmock libs (Ubuntu ships sources only)
RUN set -x \
    && mkdir -p /usr/src/googletest/build \
    && cd /usr/src/googletest/build \
    && cmake .. \
    && make -j"$(nproc)" \
    && cp -a lib/*.a /usr/lib/

# Helpful for headless rendering in CI/containers without GPU
ENV LIBGL_ALWAYS_SOFTWARE=1

# Prepare ROS 2 workspace
ENV ROS_DISTRO=galactic
RUN mkdir -p /root/ros2_ws/src
WORKDIR /root/ros2_ws

# Initialize rosdep (safe to run as root in container)
RUN rosdep init || true && rosdep update --rosdistro=galactic
ARG GAZEBO_VERSION=11
ENV GAZEBO_MODEL_PATH=/ros2_ws/src/fastbot/fastbot_description/models:/usr/share/gazebo-11/models
# Bring in your packages (replace with ROS 2 ports/branches if needed)
WORKDIR /root/ros2_ws
# TortoiseBot (ensure this repo/branch is ROS 2 compatible)
RUN git clone https://github.com/Regvith/src.git src

# Install package dependencies declared in package.xml files
WORKDIR /root/ros2_ws
RUN /bin/bash -c "source /opt/ros/galactic/setup.bash && rosdep install --from-paths src --rosdistro galactic -y --ignore-src"

# Build with colcon (ROS 2)
RUN /bin/bash -c "source /opt/ros/galactic/setup.bash && colcon build --symlink-install"

# Source overlays on shell start
RUN echo 'source /opt/ros/galactic/setup.bash' >> /root/.bashrc \
 && echo 'source /root/ros2_ws/install/setup.bash' >> /root/.bashrc

CMD ["bash"]
