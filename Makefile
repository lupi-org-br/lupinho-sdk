build:
	docker build --network host -t lupi-sdk .

run:
	docker run --rm -p 3000:3000 \
		-v $(shell pwd)/src:/lupinho/src \
		-v $(shell pwd)/dist:/lupinho/dist \
		lupi-sdk
