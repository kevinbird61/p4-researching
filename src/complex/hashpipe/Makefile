all: bmv2_switch

bmv2_switch: bmv2_switch.p4
	p4c-bm2-ss --std p4-16 \
		--target bmv2 --arch v1model \
		-o bmv2_switch.json \
		--p4runtime-file bmv2_switch.p4info \
		--p4runtime-format text bmv2_switch.p4
