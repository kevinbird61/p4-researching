all: simple

simple: simple.p4
	p4c-bm2-ss --std p4-16 \
		--target bmv2 --arch v1model \
		-o simple.json \
		--p4runtime-file simple.p4info \
		--p4runtime-format text \
		simple.p4