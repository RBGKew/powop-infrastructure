# Makefile: determine which pieces of a program need to be compiled
# Copyright (C)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

GCLOUD = gcloud
PROJECT = powop-1349
ZONE = europe-west1-d

.PHONY: get-credentials

get-credentials:
	$(GCLOUD) container clusters $@ $(NAME) \
	  --zone=$(ZONE) --project=$(PROJECT)
