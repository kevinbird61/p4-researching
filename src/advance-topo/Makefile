all: advance

advance: advance.p4
	p4c-bm2-ss --std p4-16 \
		--target bmv2 --arch v1model \
		-o advance.json \
		--p4runtime-file advance.p4info \
		--p4runtime-format text advance.p4

controller: p4_controller.py
	sudo python p4_controller.py
