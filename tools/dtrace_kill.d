#!/usr/sbin/dtrace -qs
dtrace:::BEGIN
{
    /* Print header */
    printf("%5s %12s %5s %-6s %s\n","FROM","COMMAND","SIG","TO","RESULT");
}
syscall::kill:entry
{
    /* Record target PID and signal */
    self->target = arg0;
    self->signal = arg1;
}
syscall::kill:return
{
    /* Print source, target, and result */
    printf("%5d %12s %5d %-6d %d\n",
     pid,execname,self->signal,self->target,(int)arg0);
/* Cleanup memory */
    self->target = 0;
    self->signal = 0;
}
