all: p4runtime

p4runtime: advance_tunnel.p4
	p4c-bm2-ss --std p4-16 \
		--target bmv2 --arch v1model \
		-o advance_tunnel.json \
		--p4runtime-file advance_tunnel.p4info \
		--p4runtime-format text advance_tunnel.p4
