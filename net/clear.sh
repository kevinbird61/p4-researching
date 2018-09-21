# clean all namespace
sudo ip netns delete h1
sudo ip netns delete h2
sudo ip netns delete h3
sudo ip netns delete h4

# using mn to clean (Optional)
# sudo mn -c