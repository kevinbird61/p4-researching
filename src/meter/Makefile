all: meter

meter: meter.p4
	p4c-bm2-ss --std p4-16 \
		--target bmv2 --arch v1model \
		-o meter.json \
		--p4runtime-file meter.p4info \
		--p4runtime-format text meter.p4

controller: p4_controller.py
	sudo python p4_controller.py
