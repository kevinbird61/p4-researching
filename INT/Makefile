all: int

int: int-transit.p4
	p4c-bm2-ss -o int.json \
		--p4runtime-file int.p4info \
		--p4runtime-format text int-transit.p4
