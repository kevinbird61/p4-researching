all: int-ss

int-psa: transit-psa.p4
	# FIXME: compiler need to use p4c-bm2-psa 
	p4c-bm2-ss --std p4-16 -o int.json \
		--p4runtime-file int.p4info \
		--p4runtime-format text transit-psa.p4

int-ss: transit-v1model.p4
	p4c-bm2-ss --std p4-16 \
		--target bmv2 --arch v1model \
		-o int.json \
		--p4runtime-file int.p4info \
		--p4runtime-format text transit-v1model.p4
