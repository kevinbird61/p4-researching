# Open terminal for h1~h4, with terminal name, for next step
sudo ip netns exec h1 xterm -xrm 'XTerm.vt100.allowTitleOps: false' -T host1 &
sudo ip netns exec h2 xterm -xrm 'XTerm.vt100.allowTitleOps: false' -T host2 &
sudo ip netns exec h3 xterm -xrm 'XTerm.vt100.allowTitleOps: false' -T host3 &
sudo ip netns exec h4 xterm -xrm 'XTerm.vt100.allowTitleOps: false' -T host4 &