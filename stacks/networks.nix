# global networks shared between stacks
# these cannot be specified using Docker Compose, so we specify them here
{
  public = {
    subnet = "10.0.10.0/24";
  };

  monitoring = {
    subnet = "10.0.20.0/24";
  };
}