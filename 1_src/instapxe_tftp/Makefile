NAME = instapxe/instapxe
VERSION = 1.0
C_NAME = instapxe

.PHONY: all build test tag_latest release install clean

all: clean build install

build: 
	docker build -t $(NAME):$(VERSION) -f dockerfile . 

clean: 
	docker rm -vf $(C_NAME)
	
install:
	docker run --cap-add=NET_ADMIN --network host -d -p 69:69 -p 67:67/tcp -p 67:67/udp --name $(C_NAME) $(NAME):$(VERSION)

tag_latest:
	docker tag $(NAME):$(VERSION) $(NAME):latest

release: tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"

