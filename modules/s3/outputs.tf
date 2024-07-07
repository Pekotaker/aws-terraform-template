output "output" {
  value = {
    private_bucket = module.private_bucket
    public_bucket  = module.public_bucket
    cdn            = module.cdn
  }
}


