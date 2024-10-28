#!/bin/bash

# Usage function to display help
usage() {
    echo "Usage: $0 -n <container_name> -d <host_directory> -i <image_name>"
    echo "  -n  Name of the Docker container"
    echo "  -d  Host directory to mount inside the container"
    echo "  -i  Docker image to use (default: fishros2/ros:humble-desktop-full)"
    exit 1
}

# Default values
image_name="fishros2/ros:humble-desktop-full"

# Parse command-line arguments
while getopts ":n:d:i:" opt; do
    case $opt in
        n)
            container_name=$OPTARG
            ;;
        d)
            host_directory=$OPTARG
            ;;
        i)
            image_name=$OPTARG
            ;;
        *)
            usage
            ;;
    esac
done

# Check if required arguments are provided
if [ -z "$container_name" ] || [ -z "$host_directory" ]; then
    usage
fi

echo "Creating and configuring Docker container: $container_name"

# Step 1: Run the Docker container
sudo docker run -dit --name="$container_name" \
-v "$host_directory:$host_directory" \
-v /tmp/.X11-unix:/tmp/.X11-unix \
--device=/dev/dri/renderD128 \
-v /dev:/dev \
-v /dev/dri:/dev/dri \
--device=/dev/snd \
-e DISPLAY=unix$DISPLAY \
-w "$host_directory" \
"$image_name"

# Step 2: Configure the container's environment
sudo docker exec -it "$container_name" /bin/bash -c "echo -e '\nsource /opt/ros/humble/setup.bash' >> ~/.bashrc"

# Step 3: Allow X11 access for local GUI
xhost +local:

# Step 4: Create a shortcut file for managing the container
shortcut_file="$host_directory/.fishros/bin/$container_name"
sudo bash -c "echo '#!/bin/bash' > $shortcut_file"
sudo bash -c "echo 'xhost +local: >> /dev/null' >> $shortcut_file"
sudo bash -c "echo 'echo \"请输入指令控制$container_name: 重启(r) 进入(e) 启动(s) 关闭(c) 删除(d) 测试(t):\"' >> $shortcut_file"
sudo bash -c "echo 'read choose' >> $shortcut_file"
sudo bash -c "echo 'case \$choose in' >> $shortcut_file"
sudo bash -c "echo '    s) docker start $container_name;;' >> $shortcut_file"
sudo bash -c "echo '    r) docker restart $container_name;;' >> $shortcut_file"
sudo bash -c "echo '    e) docker exec -it $container_name /bin/bash;;' >> $shortcut_file"
sudo bash -c "echo '    c) docker stop $container_name;;' >> $shortcut_file"
sudo bash -c "echo '    d) docker stop $container_name && docker rm $container_name && sudo rm -rf $shortcut_file;;' >> $shortcut_file"
sudo bash -c "echo '    t) docker exec -it $container_name /bin/bash -c \"source /ros_entrypoint.sh && ros2\";;' >> $shortcut_file"
sudo bash -c "echo 'esac' >> $shortcut_file"
sudo bash -c "echo 'newgrp docker' >> $shortcut_file"

# Step 5: Set executable permissions on the shortcut file
sudo chmod 777 "$shortcut_file"

echo "Container $container_name created and configured successfully."
echo "You can access it using the shortcut: $shortcut_file"

