all: bcast

bcast: ../bcast.p4
	p4c-bm2-ss --std p4-16 \
		--target bmv2 --arch v1model \
		-o target.json \
		--p4runtime-file target.p4info \
		--p4runtime-format text ../bcast.p4
