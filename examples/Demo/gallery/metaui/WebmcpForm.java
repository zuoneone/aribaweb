package gallery.metaui;

import ariba.ui.aribaweb.core.AWComponent;

public final class WebmcpForm extends AWComponent
{
    public String summary = "";
    public String details = "";
    public String ticketMessage;

    public boolean isStateless ()
    {
        return false;
    }

    public AWComponent createTicket ()
    {
        ticketMessage = "Ticket ready: " + summary;
        return null;
    }
}
