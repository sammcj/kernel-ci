NAME = linux-kernel
REPO = contyard.yourcompany.com/$(NAME)
TAG = $(git describe)

no_docker_build:
	@apt-get update
	@apt-get -y install coreutils fakeroot build-essential kernel-package wget xz-utils gnupg bc devscripts apt-utils initramfs-tools time aria2
	@apt-get clean
	@chmod +x buildkernel.sh
	@time ./buildkernel.sh

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
