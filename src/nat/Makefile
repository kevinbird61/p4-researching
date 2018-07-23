all: nat

nat: nat.p4
	p4c-bm2-ss --std p4-16 \
		--target bmv2 --arch v1model \
		-o nat.json \
		--p4runtime-file nat.p4info \
		--p4runtime-format text nat.p4

controller: p4_controller.py
	sudo python p4_controller.py
