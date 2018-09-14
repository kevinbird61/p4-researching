all: register

register: register.p4
	p4c-bm2-ss --std p4-16 \
		--target bmv2 --arch v1model \
		-o register.json \
		--p4runtime-file register.p4info \
		--p4runtime-format text register.p4

controller: p4_controller.py
	sudo python p4_controller.py
