/**
 * Abstract TriggerHandler base class.
 * Provides a framework for handling Salesforce trigger events.
 * Subclasses should override the appropriate before/after event methods.
 */
public abstract class TriggerHandler {

    /**
     * Main entry point for trigger execution.
     * Routes to appropriate before/after methods based on trigger context.
     */
    public void run() {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                this.beforeInsert();
            } else if (Trigger.isUpdate) {
                this.beforeUpdate();
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                this.afterInsert();
            } else if (Trigger.isUpdate) {
                this.afterUpdate();
            } else if (Trigger.isDelete) {
                this.afterDelete();
            }
        }
    }

    /**
     * Executes before insert event. Override in subclass if needed.
     */
    public virtual void beforeInsert() {
    }

    /**
     * Executes before update event. Override in subclass if needed.
     */
    public virtual void beforeUpdate() {
    }

    /**
     * Executes after insert event. Override in subclass if needed.
     */
    public virtual void afterInsert() {
    }

    /**
     * Executes after update event. Override in subclass if needed.
     */
    public virtual void afterUpdate() {
    }

    /**
     * Executes after delete event. Override in subclass if needed.
     */
    public virtual void afterDelete() {
    }
}
