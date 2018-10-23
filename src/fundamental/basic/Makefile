all: l3_forward

l3_forward: l3_forward.p4
	p4c-bm2-ss --std p4-16 \
		--target bmv2 --arch v1model \
		-o l3_forward.json \
		--p4runtime-file l3_forward.p4info \
		--p4runtime-format text l3_forward.p4
