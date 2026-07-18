module Publishing
  Account = Data.define(:id, :platform, :label, :active) do
    def _id = id
    def display_name = label
    def username = label
    def is_active = active
    def enabled = active
  end
end
