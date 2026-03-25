query 80100 "Item Color Season Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Item; Item)
        {
            column(Item_No; "No.")
            {
            }

            filter(Item_CreatedAt; SystemCreatedAt)
            {
            }

            // Assuming Item has a custom field that points to Color.Code
            dataitem(K3PF_Item_Color; "K3PF Item Color")
            {
                DataItemLink = "Item No." = Item."No.";
                SqlJoinType = InnerJoin;

                column(Color_Code; "Color Code")
                {
                }

                filter(Color_CreatedAt; SystemCreatedAt)
                {
                }

                dataitem(K3PF_Season; "K3PF Season")
                {
                    DataItemLink = Code = Item."K3PFSeason Code";
                    SqlJoinType = InnerJoin;

                    column(Season_Code; Code)
                    {
                    }

                    filter(Season_CreatedAt; SystemCreatedAt)
                    {
                    }
                }

            }


        }
    }
}