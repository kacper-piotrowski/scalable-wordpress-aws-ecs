variable "chosentype" {
  type = string
  default = "DEVELOPER"
  description = "Chosen Environment Variable (TEST, DEVELOPER, PRODUCTION)"
}

variable "chosenregion" {
  type = string
  default = "us-east-1"
  description = "Chosen Region Variable (Sandbox access on: us-east-1, us-west-2)"
}