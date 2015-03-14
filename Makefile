NAME = linux-kernel
REPO = contyard.yourcompany.com/$(NAME)
TAG = $(git describe)

build:
	docker build -t $(REPO):$(TAG) .
	@echo "Successfully built $(REPO):$(TAG)..."
	@echo "make push"

push:
	docker run -v /mnt/storage/:/mnt/storage $(REPO):$(TAG) bash -c "cp *.deb /mnt/storage/"

clean:
	docker rmi -f $(REPO):$(TAG)

ci:
	@echo RUNNING ON `hostname`
	@echo RUNNING AS `whoami`
	make build
	make push
	make clean
