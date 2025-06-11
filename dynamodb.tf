resource "aws_dynamodb_table" "rag_chunks" {
  name           = "rag-chunks"
  hash_key       = "doc_id"
  range_key      = "chunk_id"
  billing_mode   = "PAY_PER_REQUEST"

  attribute {
    name = "doc_id"
    type = "S"
  }
  attribute {
    name = "chunk_id"
    type = "S"
  }
}
