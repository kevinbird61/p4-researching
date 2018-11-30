all: basic_tutorial_switch

basic_tutorial_switch: basic_tutorial_switch.p4
	p4c-bm2-ss --std p4-16 \
		--target bmv2 --arch v1model \
		-o basic_tutorial_switch.json \
		--p4runtime-file basic_tutorial_switch.p4info \
		--p4runtime-format text basic_tutorial_switch.p4